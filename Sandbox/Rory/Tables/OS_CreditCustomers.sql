CREATE TABLE [Rory].[OS_CreditCustomers] (
    [FanID]             INT          NOT NULL,
    [CompositeID]       BIGINT       NULL,
    [SourceUID]         VARCHAR (20) NULL,
    [IssuerCustomerID]  INT          NOT NULL,
    [ClubID]            INT          NULL,
    [IsLoyalty]         INT          NOT NULL,
    [PaymentCardID]     INT          NOT NULL,
    [RewardCredit]      INT          NULL,
    [RewardBlackCredit] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Rory].[OS_CreditCustomers]([FanID] ASC);

