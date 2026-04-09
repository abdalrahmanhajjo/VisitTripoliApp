# Web Parity Matrix (VisitTipoliWeb -> Figma1)

This matrix tracks compatibility status while migrating to full web parity.

Legend:
- `exact`: same path + same behavior
- `alias`: compatibility endpoint added to match web path/shape
- `partial`: endpoint exists but payload/behavior differs
- `missing`: not implemented yet

## Auth / User

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| `POST /api/auth/login` | `POST /api/auth/login` | partial | Web accepts email/username style; payload differences remain |
| `POST /api/auth/register` | `POST /api/auth/register` | partial | Field/response differences remain |
| `GET /api/user/profile` | `GET /api/user/profile` | exact |  |
| `PATCH /api/user/profile` | `PUT /api/user/profile` | alias | Added PATCH alias |
| `GET /api/user/favourites` | `GET /api/user/saved-places` | alias | Added favourites alias |
| `PUT /api/user/favourites/:placeId` | `PUT /api/user/saved-places/:placeId` | alias | Added favourites alias |
| `DELETE /api/user/favourites/:placeId` | `DELETE /api/user/saved-places/:placeId` | alias | Added favourites alias |

## Feed / Reels

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| `GET /api/feed` | `GET /api/feed` | partial | Query semantics differ for reel/video filters |
| `GET /api/feed/post/:postId/comments` | `GET /api/feed/:id/comments` | alias | Added web-style path alias |
| `POST /api/feed/post/:postId/comments` | `POST /api/feed/:id/comments` | alias | Added web-style path alias |
| `POST /api/feed/post/:postId/like` | `POST /api/feed/:id/like` | alias | Added web-style path alias |
| `POST /api/feed/post/:postId/save` | `POST /api/feed/:id/save` | alias | Added web-style path alias |

## Deals / Promotions / Proposals

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| `GET /api/promotions` | `GET /api/offers` | alias | Mounted promotions alias to offers router |
| `GET /api/messages/my-proposals` | `GET /api/offers/my-proposals` | alias | Mounted messages/proposals aliases |
| `GET /api/messages/place-proposals` | `GET /api/offers/place-proposals` | alias | Mounted messages/proposals aliases |
| `PUT /api/messages/proposals/:id/respond` | `PUT /api/offers/proposals/:id/respond` | alias | Mounted messages/proposals aliases |

## Places / Reviews / Check-in

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| `GET /api/places/:id` | `GET /api/places/:id` | exact |  |
| `GET /api/places/:id/reviews` | `GET /api/reviews?placeId=:id` | alias | Added place-scoped reviews alias |
| `POST /api/places/:id/reviews` | `POST /api/reviews` | alias | Added place-scoped reviews alias |
| `DELETE /api/places/:id/reviews/:reviewId` | `DELETE /api/reviews/:id` | alias | Added place-scoped reviews alias |
| `POST /api/places/:id/checkin` | `POST /api/badges/check-in` | alias | Added place-scoped check-in alias |
| `GET /api/places/:id/promotions` | `GET /api/offers/place/:id` | alias | Added promotions alias |

## Trips / Sharing

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| `GET /api/user/trips` | `GET /api/user/trips` | exact |  |
| `POST /api/trip-shares` | `POST /api/trip-shares` | exact |  |
| `GET /api/trip-shares/:token` | `GET /api/trip-shares/:token` | exact |  |
| `/trip-share-requests` collaboration set | no full equivalent | missing | Planned in next parity phase |

## Business / Admin

| Web contract | Current backend | Status | Notes |
|---|---|---|---|
| business insights/sponsorship/messaging blocks | limited subset | missing | Planned in business parity phase |
| admin JWT+role auth model | `X-Admin-Key` model | partial | Bridge phase required |
