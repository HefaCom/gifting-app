import { createClient } from '@supabase/supabase-js';
import { Database } from './database.types';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  },
  global: {
    headers: {
      'x-application-name': 'gifting-system'
    }
  }
});

export const handleSupabaseError = (error: any): string => {
  console.error('Supabase error:', error);
  
  if (error?.message) {
    return error.message;
  }
  
  if (error?.error_description) {
    return error.error_description;
  }
  
  return 'An unexpected error occurred';
};

export const fetchSystemStats = async () => {
  try {
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

    // Count users per level
    usersResponse.data.forEach(user => {
      levelCounts[user.level] = (levelCounts[user.level] || 0) + 1;
    });

    // Count completed users per level
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

    return {
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
    };
  } catch (error) {
    console.error('Error fetching system stats:', error);
    throw error;
  }
};