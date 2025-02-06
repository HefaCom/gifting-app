export type UserRole = 'gifter' | 'receiver' | 'funder' | 'admin';
export type UserLevel = 'gifter' | 'beginner' | 'apprentice' | 'advanced' | 'teacher' | 'master';
export type ReferralStatus = 'pending' | 'completed';
export type GiftStatus = 'pending' | 'completed';

export interface User {
  id: string;
  full_name: string;
  email: string;
  role: UserRole;
  level: UserLevel;
  referral_code: string;
  referred_by?: string;
  status: string;
  created_at: string;
}

export interface Gift {
  id: string;
  gifter_id: string;
  receiver_id: string;
  level: UserLevel;
  status: GiftStatus;
  created_at: string;
}

export interface Referral {
  id: string;
  referrer_id: string;
  referred_id?: string;
  status: ReferralStatus;
  created_at: string;
}

export interface LevelStats {
  totalUsers: number;
  completedUsers: number;
  isReady: boolean;
}

export interface SystemStats {
  funders: number;
  maxFunders: number;
  levelStats: Record<UserLevel, LevelStats>;
}