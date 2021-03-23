## Example Request Flow

The following is a tracing of an order for a grilled chicken, 3 bananas and 3 apples at Commons for 7:00pm, using RIT funds and texting a receipt.

Actions I did during the transaction:

### Homepage

https://ondemand.rit.edu/api/config

https://ondemand.rit.edu/static/assets/manifest.json

https://ondemand.rit.edu/api/sites/1312

### Find Food (7-7:15)

https://ondemand.rit.edu/api/sites/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/getKitchenLeadTimeForStores

### Clicked on Commons

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/concepts/2162

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/concepts/2162/menus/3403

### Category Grill

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items

### Add Cart to Grilled Chicken (brought up popup)

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/5f121d554f05a8000c1b8822

### Add to cart

https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders

### Category Grab and Go

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items

### Add to Cart to Banana, brought up popup menu, clicked Add to cart

https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders/919a7043-3255-47c4-bd58-7f5c3d7d4ce0

### Add to Cart to Apple, brought up popup menu, clicked Add to cart

https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders/919a7043-3255-47c4-bd58-7f5c3d7d4ce0

### Category Salads

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/get-items

### Add Cart to Salad (brought up popup)

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/kiosk-items/600892ae48f8a6000c593cbd

### Add to cart

https://ondemand.rit.edu/api/order/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/orders/919a7043-3255-47c4-bd58-7f5c3d7d4ce0

### Went through payment, and clicked "Payment" button

https://ondemand.rit.edu/api/atrium/accountInquiry

https://ondemand.rit.edu/api/sites/1312/dc9df36d-8a64-42cf-b7c1-fa041f5f3cfd/getRevenueCategory

https://ondemand.rit.edu/api/atrium/getAtriumTendersFromPaymentTypeList

### Clicked "RIT Funds" to pay

https://ondemand.rit.edu/api/order/getPaymentTenderInfo

https://ondemand.rit.edu/api/atrium/authAtriumPayment

https://ondemand.rit.edu/api/order/capacityCheck

https://ondemand.rit.edu/api/order/createMultiPaymentClosedOrder

### Clicked "Text receipt" and sent it

https://ondemand.rit.edu/api/communication/getSMSReceipt

https://ondemand.rit.edu/api/communication/sendSMSReceipt