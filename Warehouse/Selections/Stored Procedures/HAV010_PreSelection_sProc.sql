﻿-- =============================================
Select FanID
Into #CoreCustomers
From Relational.Customer_RBSGSegments
WHERE CustomerSegment NOT LIKE '%v%'
AND EndDate IS NULL