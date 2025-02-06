"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { User, Gift, Referral } from "@/lib/types";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ThemeToggle } from "@/components/theme-toggle";
import { toast } from "sonner";
import {
  Users,
  Gift as GiftIcon,
  UserPlus,
  LogOut,
  Search,
  TrendingUp,
  BarChart3,
  Calendar,
  Filter,
} from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { motion } from "framer-motion";

export default function AdminDashboard() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<User[]>([]);
  const [gifts, setGifts] = useState<Gift[]>([]);
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [isAdmin, setIsAdmin] = useState(false);
  const [selectedTimeframe, setSelectedTimeframe] = useState("all");
  const [selectedStatus, setSelectedStatus] = useState("all");

  useEffect(() => {
    checkAdminAccess();
  }, []);

  const checkAdminAccess = async () => {
    try {
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) throw sessionError;
      
      if (!session) {
        router.push("/auth/sign-in");
        return;
      }

      const { data: users, error: usersError } = await supabase
        .from("users")
        .select("*")
        .eq("id", session.user.id);

      if (usersError) throw usersError;
      
      const userData = users?.[0];
      if (!userData) {
        toast.error("User not found");
        router.push("/auth/sign-in");
        return;
      }

      if (!["admin@gifting.system", "admin@app.com"].includes(userData.email)) {
        toast.error("Unauthorized access");
        router.push("/dashboard");
        return;
      }

      setIsAdmin(true);
      fetchData();
    } catch (error: any) {
      console.error("Admin access error:", error);
      toast.error("Error checking admin access: " + error.message);
      router.push("/dashboard");
    }
  };

  const fetchData = async () => {
    try {
      const [usersResponse, giftsResponse, referralsResponse] = await Promise.all([
        supabase.from("users").select("*").order("created_at", { ascending: false }),
        supabase.from("gifts").select("*").order("created_at", { ascending: false }),
        supabase.from("referrals").select("*").order("created_at", { ascending: false }),
      ]);

      if (usersResponse.error) throw usersResponse.error;
      if (giftsResponse.error) throw giftsResponse.error;
      if (referralsResponse.error) throw referralsResponse.error;

      setUsers(usersResponse.data || []);
      setGifts(giftsResponse.data || []);
      setReferrals(referralsResponse.data || []);
    } catch (error: any) {
      console.error("Data fetching error:", error);
      toast.error("Error fetching data: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      router.push("/auth/sign-in");
    } catch (error: any) {
      console.error("Sign out error:", error);
      toast.error("Error signing out: " + error.message);
    }
  };

  const filterData = (data: any[], term: string) => {
    return data.filter(item => {
      const searchString = term.toLowerCase();
      const matchesSearch = Object.values(item).some(
        value => value && value.toString().toLowerCase().includes(searchString)
      );
      
      if (selectedTimeframe !== "all") {
        const date = new Date(item.created_at);
        const now = new Date();
        const daysDiff = (now.getTime() - date.getTime()) / (1000 * 3600 * 24);
        
        if (selectedTimeframe === "week" && daysDiff > 7) return false;
        if (selectedTimeframe === "month" && daysDiff > 30) return false;
        if (selectedTimeframe === "year" && daysDiff > 365) return false;
      }

      if (selectedStatus !== "all" && item.status !== selectedStatus) return false;

      return matchesSearch;
    });
  };

  const filteredUsers = filterData(users, searchTerm);
  const filteredGifts = filterData(gifts, searchTerm);

  const getStats = () => {
    const totalUsers = users.length;
    const activeUsers = users.filter(u => u.status === "active").length;
    const completedGifts = gifts.filter(g => g.status === "completed").length;
    const pendingGifts = gifts.filter(g => g.status === "pending").length;
    const successfulReferrals = referrals.filter(r => r.status === "completed").length;

    return {
      totalUsers,
      activeUsers,
      completedGifts,
      pendingGifts,
      successfulReferrals,
    };
  };

  const stats = getStats();

  if (!isAdmin || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-lg font-medium text-muted-foreground animate-pulse">
          {loading ? "Loading..." : "Checking admin access..."}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto p-4 sm:p-6 lg:p-8 space-y-8">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
        >
          <div>
            <h1 className="text-3xl font-bold">Admin Dashboard</h1>
            <p className="text-muted-foreground">Manage users, gifts, and system statistics</p>
          </div>
          <div className="flex items-center gap-4">
            <ThemeToggle />
            <Button variant="outline" onClick={handleSignOut}>
              <LogOut className="mr-2 h-4 w-4" />
              Sign Out
            </Button>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4"
        >
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalUsers}</div>
              <p className="text-xs text-muted-foreground mt-2">
                {stats.activeUsers} active users
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Completed Gifts</CardTitle>
              <GiftIcon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.completedGifts}</div>
              <p className="text-xs text-muted-foreground mt-2">
                {stats.pendingGifts} pending
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Referrals</CardTitle>
              <UserPlus className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.successfulReferrals}</div>
              <p className="text-xs text-muted-foreground mt-2">
                Successful referrals
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Conversion Rate</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {((stats.completedGifts / (stats.completedGifts + stats.pendingGifts)) * 100).toFixed(1)}%
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                Gift completion rate
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">User Growth</CardTitle>
              <BarChart3 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {(stats.totalUsers / 100).toFixed(1)}x
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                Growth multiplier
              </p>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="flex flex-col sm:flex-row gap-4 items-center"
        >
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search users, gifts..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9"
            />
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setSelectedTimeframe(selectedTimeframe === "all" ? "week" : "all")}
            >
              <Calendar className="h-4 w-4 mr-2" />
              {selectedTimeframe === "all" ? "All Time" : "This Week"}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setSelectedStatus(selectedStatus === "all" ? "completed" : "all")}
            >
              <Filter className="h-4 w-4 mr-2" />
              {selectedStatus === "all" ? "All Status" : "Completed"}
            </Button>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <Tabs defaultValue="users" className="space-y-6">
            <TabsList>
              <TabsTrigger value="users">Users</TabsTrigger>
              <TabsTrigger value="gifts">Gifts</TabsTrigger>
            </TabsList>

            <TabsContent value="users">
              <Card>
                <CardHeader>
                  <CardTitle>Users</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="rounded-md border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Name</TableHead>
                          <TableHead>Email</TableHead>
                          <TableHead>Level</TableHead>
                          <TableHead>Role</TableHead>
                          <TableHead>Joined</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredUsers.map((user) => (
                          <TableRow key={user.id}>
                            <TableCell className="font-medium">{user.full_name}</TableCell>
                            <TableCell>{user.email}</TableCell>
                            <TableCell className="capitalize">{user.level}</TableCell>
                            <TableCell>
                              <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                                user.role === 'admin'
                                  ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                                  : user.role === 'funder'
                                  ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                  : 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400'
                              }`}>
                                {user.role}
                              </span>
                            </TableCell>
                            <TableCell>
                              {new Date(user.created_at).toLocaleDateString()}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="gifts">
              <Card>
                <CardHeader>
                  <CardTitle>Gifts</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="rounded-md border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Gifter</TableHead>
                          <TableHead>Receiver</TableHead>
                          <TableHead>Level</TableHead>
                          <TableHead>Status</TableHead>
                          <TableHead>Date</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredGifts.map((gift) => (
                          <TableRow key={gift.id}>
                            <TableCell>
                              {users.find(u => u.id === gift.gifter_id)?.full_name}
                            </TableCell>
                            <TableCell>
                              {users.find(u => u.id === gift.receiver_id)?.full_name}
                            </TableCell>
                            <TableCell className="capitalize">{gift.level}</TableCell>
                            <TableCell>
                              <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                                gift.status === "completed"
                                  ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                                  : "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
                              }`}>
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
            </TabsContent>
          </Tabs>
        </motion.div>
      </div>
    </div>
  );
}