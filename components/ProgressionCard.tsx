"use client";

import { useEffect, useState } from "react";
import { UserLevel, SystemStats } from "@/lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Lock, Unlock, Gift, Users, Star } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";
import { motion } from "framer-motion";

interface ProgressionCardProps {
  currentLevel: UserLevel;
  giftsReceived: number;
}

const LEVEL_INFO = {
  gifter: { order: 0, title: "Gifter", description: "Start your giving journey", icon: Gift },
  beginner: { order: 1, title: "Beginner", description: "Learn the basics of giving", icon: Star },
  apprentice: { order: 2, title: "Apprentice", description: "Develop your giving skills", icon: Star },
  advanced: { order: 3, title: "Advanced", description: "Master the art of giving", icon: Star },
  teacher: { order: 4, title: "Teacher", description: "Guide others in their journey", icon: Users },
  master: { order: 5, title: "Master", description: "Achieve giving excellence", icon: Star },
};

export function ProgressionCard({ currentLevel, giftsReceived }: ProgressionCardProps) {
  const [systemStats, setSystemStats] = useState<SystemStats | null>(null);
  const [loading, setLoading] = useState(true);
  const currentLevelOrder = LEVEL_INFO[currentLevel].order;

  useEffect(() => {
    fetchSystemStats();
    
    const subscription = supabase
      .channel('system-stats')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'gifts' }, () => {
        fetchSystemStats();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'users' }, () => {
        fetchSystemStats();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const fetchSystemStats = async () => {
    try {
      setLoading(true);
      
      const [fundersResponse, usersResponse, giftsResponse] = await Promise.all([
        supabase.from("users").select("id").eq("role", "funder"),
        supabase.from("users").select("level, id"),
        supabase.from("gifts").select("receiver_id, level, status").eq("status", "completed")
      ]);

      if (fundersResponse.error) throw fundersResponse.error;
      if (usersResponse.error) throw usersResponse.error;
      if (giftsResponse.error) throw giftsResponse.error;

      const levelCounts: Record<string, number> = {};
      const completedCounts: Record<string, number> = {};

      usersResponse.data.forEach(user => {
        levelCounts[user.level] = (levelCounts[user.level] || 0) + 1;
      });

      const giftsByReceiver = giftsResponse.data.reduce((acc, gift) => {
        if (!acc[gift.receiver_id]) {
          acc[gift.receiver_id] = {};
        }
        if (!acc[gift.receiver_id][gift.level]) {
          acc[gift.receiver_id][gift.level] = 0;
        }
        acc[gift.receiver_id][gift.level]++;
        return acc;
      }, {} as Record<string, Record<string, number>>);

      Object.values(giftsByReceiver).forEach(receiverGifts => {
        Object.entries(receiverGifts).forEach(([level, count]) => {
          if (count >= 8) {
            completedCounts[level] = (completedCounts[level] || 0) + 1;
          }
        });
      });

      setSystemStats({
        funders: fundersResponse.data.length,
        maxFunders: 8,
        levelStats: {
          gifter: { totalUsers: levelCounts.gifter || 0, completedUsers: completedCounts.gifter || 0, isReady: false },
          beginner: { totalUsers: levelCounts.beginner || 0, completedUsers: completedCounts.beginner || 0, isReady: false },
          apprentice: { totalUsers: levelCounts.apprentice || 0, completedUsers: completedCounts.apprentice || 0, isReady: false },
          advanced: { totalUsers: levelCounts.advanced || 0, completedUsers: completedCounts.advanced || 0, isReady: false },
          teacher: { totalUsers: levelCounts.teacher || 0, completedUsers: completedCounts.teacher || 0, isReady: false },
          master: { totalUsers: levelCounts.master || 0, completedUsers: completedCounts.master || 0, isReady: false },
        }
      });
    } catch (error: any) {
      console.error("Error fetching system stats:", error);
      toast.error("Failed to load progression data");
    } finally {
      setLoading(false);
    }
  };

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

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <Card key={i} className="animate-pulse">
            <CardHeader>
              <div className="h-6 bg-muted rounded w-1/3" />
            </CardHeader>
            <CardContent>
              <div className="h-4 bg-muted rounded w-2/3 mb-4" />
              <div className="h-2 bg-muted rounded w-full" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      {Object.entries(LEVEL_INFO).map(([level, info]) => {
        const isCurrentLevel = level === currentLevel;
        const isUnlocked = LEVEL_INFO[level as UserLevel].order <= currentLevelOrder;
        const levelStats = systemStats?.levelStats[level as UserLevel];
        const progressCount = isCurrentLevel ? (giftsReceived % 8) : (levelStats?.completedUsers || 0);
        const progressPercentage = (progressCount / 8) * 100;
        const Icon = info.icon;

        return (
          <motion.div key={level} variants={item}>
            <Card className={`relative overflow-hidden transition-all duration-300 hover:shadow-lg ${
              isCurrentLevel ? 'ring-2 ring-primary' : ''
            }`}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-lg font-medium flex items-center gap-2">
                  <Icon className="h-5 w-5" />
                  {info.title}
                </CardTitle>
                {isUnlocked ? (
                  <Unlock className="h-4 w-4 text-muted-foreground" />
                ) : (
                  <Lock className="h-4 w-4 text-muted-foreground" />
                )}
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground mb-4">{info.description}</p>
                {levelStats && (
                  <div className="flex items-center gap-2 mb-2">
                    <Users className="h-4 w-4" />
                    <span className="text-sm">
                      {levelStats.completedUsers}/{levelStats.totalUsers} completed
                    </span>
                  </div>
                )}
                {isCurrentLevel && (
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Your Progress</span>
                      <Badge variant="secondary" className="animate-pulse">
                        <Gift className="h-3 w-3 mr-1" />
                        {progressCount}/8 gifts
                      </Badge>
                    </div>
                    <div className="w-full bg-secondary rounded-full h-2 overflow-hidden">
                      <motion.div
                        className="h-full bg-primary"
                        initial={{ width: 0 }}
                        animate={{ width: `${progressPercentage}%` }}
                        transition={{ duration: 0.5, ease: "easeOut" }}
                      />
                    </div>
                    {levelStats?.isReady && (
                      <Badge variant="secondary" className="mt-2 animate-pulse">
                        Level Ready for Progression
                      </Badge>
                    )}
                  </div>
                )}
                {!isCurrentLevel && (
                  <Badge variant={isUnlocked ? "secondary" : "outline"} className="mt-2">
                    {isUnlocked ? "Completed" : "Locked"}
                  </Badge>
                )}
              </CardContent>
            </Card>
          </motion.div>
        );
      })}
    </motion.div>
  );
}