# Cancel Subscription API Reference

This document outlines how to interact with the subscription cancellation endpoint.

## Endpoint

**URL:** `https://api-6ais2ap6ia-uc.a.run.app/api/cancel-subscription`
**Method:** `POST`

## Headers

| Header | Value | Description |
| :--- | :--- | :--- |
| `Content-Type` | `application/json` | Required |
| `Authorization` | `Bearer <YOUR_ID_TOKEN>` | Firebase Auth ID Token |

## Request Body

The request body must be a JSON object containing the `businessId`.

```json
{
  "businessId": "YOUR_BUSINESS_ID_HERE"
}
```

> **Note:** The `businessId` field accepts either the Firestore Document ID of the business OR the `companyCode`.

## Example Request (cURL)

```bash
curl -X POST https://api-6ais2ap6ia-uc.a.run.app/api/cancel-subscription \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -d '{
    "businessId": "example_business_id_123"
  }'
```

## Responses

### Success (200 OK)

```json
{
  "status": "success"
}
```

### Error (400 Bad Request)

Missing `businessId` or subscription not found.

```json
{
  "error": "Missing businessId"
}
```
