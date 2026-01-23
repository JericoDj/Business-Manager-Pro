"use server";



import { Polar } from "@polar-sh/sdk";
import { redirect } from "next/navigation";

const polar = new Polar({
  accessToken: process.env.POLAR_ACCESS_TOKEN,
});


export const subscriptionPlusCheckout = async () => {
const checkout = await polar.checkouts.create({
  products: [
    "46b04f9e-0d98-45b2-a7eb-eb1a3521ba01"
    server
  ],
  successUrl: process.env.POLAR_SUCCESS_URL
});

redirect(checkout.url)