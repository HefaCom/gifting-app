"use client";

import { Button } from "@/components/ui/button";
import Link from "next/link";
import { Shield } from "lucide-react";
import { motion } from "framer-motion";
import { useEffect, useState } from "react";

export default function Home() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <div className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden bg-gradient-to-b from-background to-muted">
      {/* Animated background elements - only render on client side */}
      {mounted && (
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(20)].map((_, i) => {
            // Pre-calculate random values to ensure consistency
            const width = 50 + Math.floor(Math.random() * 250);
            const height = 50 + Math.floor(Math.random() * 250);
            const left = Math.floor(Math.random() * 100);
            const top = Math.floor(Math.random() * 100);
            const duration = 3 + Math.floor(Math.random() * 5);
            const delay = Math.floor(Math.random() * 2);

            return (
              <motion.div
                key={i}
                className="absolute bg-primary/5 rounded-full"
                initial={{ scale: 0, opacity: 0 }}
                animate={{
                  scale: [1, 1.2, 1],
                  opacity: [0.3, 0.5, 0.3],
                }}
                transition={{
                  duration,
                  repeat: Infinity,
                  repeatType: "reverse",
                  delay,
                }}
                style={{
                  width,
                  height,
                  left: `${left}%`,
                  top: `${top}%`,
                }}
              />
            );
          })}
        </div>
      )}

      {/* Content */}
      <div className="relative max-w-3xl mx-auto text-center space-y-8 p-8">
        <motion.h1
          className="text-5xl sm:text-6xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-primary to-primary/50"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          Welcome to the Gifting System
        </motion.h1>

        <motion.p
          className="text-xl text-muted-foreground"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          Join our community of givers and receivers. Progress through levels and
          build meaningful connections.
        </motion.p>

        <motion.div
          className="flex flex-col sm:flex-row gap-4 justify-center items-center"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
        >
          <Button asChild size="lg" className="w-full sm:w-auto">
            <Link href="/auth/sign-in">Sign In</Link>
          </Button>
          {/* <Button asChild variant="outline" size="lg" className="w-full sm:w-auto">
            <Link href="/auth/sign-up">Sign Up</Link>
          </Button> */}
          <Button
            asChild
            variant="ghost"
            size="lg"
            className="flex items-center gap-2 w-full sm:w-auto"
          >
            <Link href="#">
            {/* /auth/admin/sign-in */}
              <Shield className="h-4 w-4" />
              Admin Sign In
            </Link>
          </Button>
        </motion.div>

        {/* Features */}
        <motion.div
          className="grid grid-cols-1 sm:grid-cols-3 gap-6 mt-16"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <div className="p-6 rounded-lg bg-card border">
            <h3 className="text-lg font-semibold mb-2">Progress System</h3>
            <p className="text-sm text-muted-foreground">
              Advance through levels as you participate in the gifting community
            </p>
          </div>
          <div className="p-6 rounded-lg bg-card border">
            <h3 className="text-lg font-semibold mb-2">Community</h3>
            <p className="text-sm text-muted-foreground">
              Connect with like-minded individuals who share your values
            </p>
          </div>
          <div className="p-6 rounded-lg bg-card border">
            <h3 className="text-lg font-semibold mb-2">Rewards</h3>
            <p className="text-sm text-muted-foreground">
              Earn recognition and unlock new opportunities as you grow
            </p>
          </div>
        </motion.div>
      </div>
    </div>
  );
}