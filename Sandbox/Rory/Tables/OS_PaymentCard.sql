CREATE TABLE [Rory].[OS_PaymentCard] (
    [FanID]            INT          NOT NULL,
    [CompositeID]      BIGINT       NULL,
    [SourceUID]        VARCHAR (20) NULL,
    [IssuerCustomerID] INT          NOT NULL,
    [ClubID]           INT          NULL,
    [IsLoyalty]        INT          NOT NULL,
    [PaymentCardID]    INT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_PaymentCardID]
    ON [Rory].[OS_PaymentCard]([PaymentCardID] ASC);

