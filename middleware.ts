import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const ADMIN_EMAILS = ['admin@gifting.system', 'admin@app.com'];

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });

  try {
    const {
      data: { session },
      error: sessionError,
    } = await supabase.auth.getSession();

    if (sessionError) {
      return NextResponse.redirect(new URL('/auth/sign-in', req.url));
    }

    // Protect dashboard and admin routes
    if (req.nextUrl.pathname.startsWith('/dashboard') || req.nextUrl.pathname.startsWith('/admin')) {
      if (!session) {
        return NextResponse.redirect(new URL('/auth/sign-in', req.url));
      }

      // For admin routes, verify admin email
      if (req.nextUrl.pathname.startsWith('/admin')) {
        if (!session.user.email || !ADMIN_EMAILS.includes(session.user.email)) {
          return NextResponse.redirect(new URL('/dashboard', req.url));
        }
      }

      // For dashboard, prevent admin access
      if (req.nextUrl.pathname.startsWith('/dashboard')) {
        if (session.user.email && ADMIN_EMAILS.includes(session.user.email)) {
          return NextResponse.redirect(new URL('/admin', req.url));
        }
      }
    }

    // Redirect authenticated users away from auth pages
    if (session && (req.nextUrl.pathname.startsWith('/auth/') || req.nextUrl.pathname === '/')) {
      if (session.user.email && ADMIN_EMAILS.includes(session.user.email)) {
        return NextResponse.redirect(new URL('/admin', req.url));
      }
      return NextResponse.redirect(new URL('/dashboard', req.url));
    }

    return res;
  } catch (error) {
    // If there's any error, redirect to sign in
    return NextResponse.redirect(new URL('/auth/sign-in', req.url));
  }
}

export const config = {
  matcher: ['/', '/dashboard/:path*', '/admin/:path*', '/auth/:path*'],
};