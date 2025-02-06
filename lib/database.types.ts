export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          full_name: string
          email: string
          role: string
          level: string
          referral_code: string
          referred_by: string | null
          status: string
          created_at: string
        }
        Insert: {
          id?: string
          full_name: string
          email: string
          role?: string
          level?: string
          referral_code?: string
          referred_by?: string | null
          status?: string
          created_at?: string
        }
        Update: {
          id?: string
          full_name?: string
          email?: string
          role?: string
          level?: string
          referral_code?: string
          referred_by?: string | null
          status?: string
          created_at?: string
        }
      }
      gifts: {
        Row: {
          id: string
          gifter_id: string
          receiver_id: string
          level: string
          status: string
          created_at: string
        }
        Insert: {
          id?: string
          gifter_id: string
          receiver_id: string
          level: string
          status?: string
          created_at?: string
        }
        Update: {
          id?: string
          gifter_id?: string
          receiver_id?: string
          level?: string
          status?: string
          created_at?: string
        }
      }
      referrals: {
        Row: {
          id: string
          referrer_id: string
          referred_id: string | null
          status: string
          created_at: string
        }
        Insert: {
          id?: string
          referrer_id: string
          referred_id?: string | null
          status?: string
          created_at?: string
        }
        Update: {
          id?: string
          referrer_id?: string
          referred_id?: string | null
          status?: string
          created_at?: string
        }
      }
    }
  }
}