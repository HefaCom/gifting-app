import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { supabase, handleSupabaseError, fetchSystemStats } from "@/lib/supabase";
import { Heart, Coins, TrendingUp } from "lucide-react";
import { SystemStats, User } from "@/lib/types";
import { motion, AnimatePresence } from "framer-motion";
import { Badge } from "./ui/badge";
interface DonationCardProps {
  userId: string;
  receiverId: string;
  currentLevel: string;
}

export function DonationCard({ userId, receiverId, currentLevel }: DonationCardProps) {
  const [amount, setAmount] = useState("");
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [systemStats, setSystemStats] = useState<SystemStats | null>(null);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [showSuccess, setShowSuccess] = useState(false);

  useEffect(() => {
    let mounted = true;

    const loadInitialData = async () => {
      try {
        const [stats, { data: user, error: userError }] = await Promise.all([
          fetchSystemStats(),
          supabase.from("users").select("*").eq("id", userId).single()
        ]);

        if (!mounted) return;

        if (userError) throw userError;
        if (!user) throw new Error("User not found");

        setSystemStats(stats);
        setCurrentUser(user);
      } catch (error) {
        console.error("Error loading initial data:", error);
        toast.error(handleSupabaseError(error));
      } finally {
        if (mounted) {
          setInitialLoading(false);
        }
      }
    };

    loadInitialData();

    const subscription = supabase
      .channel('donation-updates')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'gifts' },
        () => loadInitialData()
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'users' },
        () => loadInitialData()
      )
      .subscribe();

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [userId]);

  const handleDonation = async () => {
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
      toast.error("Please enter a valid amount");
      return;
    }

    if (!currentUser || !systemStats) {
      toast.error("Unable to process donation at this time");
      return;
    }

    if (currentUser.role === "gifter" && systemStats.funders >= systemStats.maxFunders) {
      toast.error("Maximum number of funders reached");
      return;
    }

    setLoading(true);

    try {
      const { error: giftError } = await supabase.from("gifts").insert([{
        gifter_id: userId,
        receiver_id: receiverId,
        level: currentLevel,
        status: "completed",
      }]);

      if (giftError) throw giftError;

      if (currentUser.role === "gifter" && systemStats.funders < systemStats.maxFunders) {
        const { error: updateError } = await supabase
          .from("users")
          .update({ role: "funder" })
          .eq("id", userId);

        if (updateError) throw updateError;
      }

      setShowSuccess(true);
      setTimeout(() => setShowSuccess(false), 3000);
      setAmount("");
    } catch (error) {
      console.error("Donation error:", error);
      toast.error(handleSupabaseError(error));
    } finally {
      setLoading(false);
    }
  };

  if (initialLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Heart className="h-5 w-5 text-destructive" />
            Make a Donation
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4 animate-pulse">
            <div className="h-4 bg-muted rounded w-1/3" />
            <div className="h-10 bg-muted rounded" />
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="relative overflow-hidden">
      <AnimatePresence>
        {showSuccess && (
          <motion.div
            initial={{ opacity: 0, y: -50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -50 }}
            className="absolute inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center z-10"
          >
            <div className="text-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-green-100 text-green-600 mb-4"
              >
                <TrendingUp className="h-8 w-8" />
              </motion.div>
              <h3 className="text-lg font-semibold mb-2">Donation Successful!</h3>
              <p className="text-sm text-muted-foreground">Thank you for your contribution</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Heart className="h-5 w-5 text-destructive" />
          Make a Donation
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {systemStats && (
          <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
            <div className="flex items-center gap-2">
              <Coins className="h-5 w-5 text-primary" />
              <div>
                <p className="text-sm font-medium">Current Funders</p>
                <p className="text-2xl font-bold">{systemStats.funders}/{systemStats.maxFunders}</p>
              </div>
            </div>
            {currentUser?.role === "gifter" && systemStats.funders >= systemStats.maxFunders && (
              <Badge variant="destructive">Positions Full</Badge>
            )}
          </div>
        )}
        <div className="space-y-2">
          <Label htmlFor="amount">Amount</Label>
          <div className="flex gap-2">
            <div className="relative flex-1">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">$</span>
              <Input
                id="amount"
                type="number"
                min="1"
                placeholder="Enter amount"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="pl-8"
                disabled={loading}
              />
            </div>
            <Button 
              onClick={handleDonation} 
              disabled={
                loading || 
                !currentUser || 
                !systemStats || 
                (currentUser?.role === "gifter" && systemStats?.funders >= systemStats?.maxFunders)
              }
              className="min-w-[100px]"
            >
              {loading ? (
                <motion.div
                  animate={{ rotate: 360 }}
                  transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                >
                  <Coins className="h-4 w-4" />
                </motion.div>
              ) : (
                "Donate"
              )}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}