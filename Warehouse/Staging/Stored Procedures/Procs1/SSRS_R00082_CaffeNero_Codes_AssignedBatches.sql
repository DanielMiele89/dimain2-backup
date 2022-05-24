CREATE Procedure Staging.SSRS_R00082_CaffeNero_Codes_AssignedBatches
as
Select AssignedDate,[MembersAssignedBatch],convert(varchar,AssignedDate,111)+' - '+Cast([MembersAssignedBatch] as varchar(5)) as Batch
From [Relational].[RedemptionCodeAssignment] as rca

Order by [MembersAssignedBatch] desc