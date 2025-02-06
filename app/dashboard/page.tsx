"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { User, Gift, Referral } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ProgressionCard } from "@/components/ProgressionCard";
import { DonationCard } from "@/components/DonationCard";
import { ThemeToggle } from "@/components/theme-toggle";
import { toast } from "sonner";
import { motion } from "framer-motion";
import {
  Gift as GiftIcon,
  Share2,
  LogOut,
  Shield,
  Users,
  TrendingUp,
  Award,
} from "lucide-react";

export default function Dashboard() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [gifts, setGifts] = useState<Gift[]>([]);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        
        if (sessionError || !session) {
          router.push("/auth/sign-in");
          return;
        }

        const { data: userData, error: userError } = await supabase
          .from("users")
          .select("*")
          .eq("id", session.user.id)
          .single();

        if (userError || !userData) {
          await supabase.auth.signOut();
          router.push("/auth/sign-in");
          return;
        }

        const [giftsResponse, referralsResponse] = await Promise.all([
          supabase
            .from("gifts")
            .select("*")
            .or(`gifter_id.eq.${session.user.id},receiver_id.eq.${session.user.id}`)
            .order('created_at', { ascending: false }),
          supabase
            .from("referrals")
            .select("*")
            .eq("referrer_id", session.user.id)
            .order('created_at', { ascending: false })
        ]);

        setUser(userData);
        setGifts(giftsResponse.data || []);
        setReferrals(referralsResponse.data || []);
      } catch (error: any) {
        console.error("Dashboard error:", error);
        toast.error("Error loading dashboard");
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();

    const giftsSubscription = supabase
      .channel('gifts-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'gifts',
          filter: user?.id ? `gifter_id=eq.${user.id} OR receiver_id=eq.${user.id}` : undefined
        },
        async () => {
          const { data: userData } = await supabase
            .from("users")
            .select("*")
            .eq("id", user?.id)
            .single();

          if (userData) {
            setUser(userData);
          }

          const { data: giftsData } = await supabase
            .from("gifts")
            .select("*")
            .or(`gifter_id.eq.${user?.id},receiver_id.eq.${user?.id}`)
            .order('created_at', { ascending: false });

          if (giftsData) {
            setGifts(giftsData);
          }
        }
      )
      .subscribe();

    return () => {
      giftsSubscription.unsubscribe();
    };
  }, [router, user?.id]);

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      router.push("/auth/sign-in");
    } catch (error: any) {
      console.error("Sign out error:", error);
      toast.error("Error signing out");
    }
  };

  const copyReferralLink = () => {
    if (!user?.referral_code) return;
    const link = `${window.location.origin}/auth/sign-up?code=${user.referral_code}`;
    navigator.clipboard.writeText(link);
    toast.success("Referral link copied to clipboard!");
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-lg animate-pulse">Loading...</div>
      </div>
    );
  }

  if (!user) return null;

  const giftsReceived = gifts.filter(g => g.receiver_id === user.id && g.status === "completed").length;
  const isAdmin = user.email === "admin@gifting.system";

  const container = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const item = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0 }
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-8">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
        >
          <div>
            <h1 className="text-3xl font-bold">Welcome, {user.full_name}</h1>
            <p className="text-muted-foreground">Track your progress and manage your gifts</p>
          </div>
          <div className="flex items-center gap-4">
            <ThemeToggle />
            {isAdmin && (
              <Button variant="outline" onClick={() => router.push("/admin")}>
                <Shield className="mr-2 h-4 w-4" />
                Admin Dashboard
              </Button>
            )}
            <Button variant="outline" onClick={handleSignOut}>
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </Button>
          </div>
        </motion.div>

        <motion.div
          variants={container}
          initial="hidden"
          animate="show"
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
        >
          <motion.div variants={item}>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Level Progress</CardTitle>
                <Award className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold capitalize">{user.level}</div>
                <Progress
                  value={(giftsReceived % 8 / 8) * 100}
                  className="mt-4"
                />
                <p className="text-xs text-muted-foreground mt-2">
                  {giftsReceived % 8}/8 gifts at current level
                </p>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={item}>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Gifts</CardTitle>
                <GiftIcon className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{gifts.length}</div>
                <p className="text-xs text-muted-foreground mt-2">
                  Gifts exchanged
                </p>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={item}>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Referrals</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{referrals.length}</div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={copyReferralLink}
                  className="w-full mt-2"
                >
                  <Share2 className="h-4 w-4 mr-2" />
                  Share Link
                </Button>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div variants={item}>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Growth</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {((giftsReceived / 8) * 100).toFixed(0)}%
                </div>
                <p className="text-xs text-muted-foreground mt-2">
                  Level completion
                </p>
              </CardContent>
            </Card>
          </motion.div>
        </motion.div>

        <motion.div
          variants={container}
          initial="hidden"
          animate="show"
          className="grid grid-cols-1 lg:grid-cols-2 gap-6"
        >
          <motion.div variants={item}>
            <ProgressionCard currentLevel={user.level} giftsReceived={giftsReceived} />
          </motion.div>

          <motion.div variants={item}>
            <DonationCard userId={user.id} receiverId={user.id} currentLevel={user.level} />
          </motion.div>
        </motion.div>

        <motion.div
          variants={item}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <GiftIcon className="h-5 w-5" />
                Recent Gifts
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Type</TableHead>
                      <TableHead>Level</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Date</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {gifts.slice(0, 5).map((gift) => (
                      <TableRow key={gift.id}>
                        <TableCell className="font-medium">
                          {gift.gifter_id === user.id ? "Sent" : "Received"}
                        </TableCell>
                        <TableCell className="capitalize">{gift.level}</TableCell>
                        <TableCell>
                          <span
                            className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                              gift.status === "completed"
                                ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                                : "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
                            }`}
                          >
                            {gift.status}
                          </span>
                        </TableCell>
                        <TableCell>
                          {new Date(gift.created_at).toLocaleDateString()}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}