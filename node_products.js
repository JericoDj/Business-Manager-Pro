npm install @polar-sh/sdk


import { Polar } from "@polar-sh/sdk";



const polar = new Polar({
  accessToken: process.env.POLAR_ACCESS_TOKEN,
});

const checkout = await polar.checkouts.create({
  products: [
    "1c8032ef-7bc2-49d0-83e8-a70175435281",
    "a80f9756-04f8-499b-8b87-b4e873a0e684",
    "46b04f9e-0d98-45b2-a7eb-eb1a3521ba01",
    "4804c622-daa3-448c-b1a4-eb33f24f4d99"
  ],
  successUrl: process.env.POLAR_SUCCESS_URL
});

redirect(checkout.url)