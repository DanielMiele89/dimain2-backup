CREATE TABLE [InsightArchive].[AviosRedemptionPush_20180322_Redemptions] (
    [Email]                   VARCHAR (100) NULL,
    [FanID]                   INT           NOT NULL,
    [FirstName]               VARCHAR (50)  NULL,
    [LastName]                VARCHAR (50)  NULL,
    [ClubName]                VARCHAR (7)   NULL,
    [IsLoyalty]               BIT           NULL,
    [Loyalty]                 VARCHAR (5)   NULL,
    [IsAvios]                 VARCHAR (10)  NULL,
    [InitialRedeemDate]       DATETIME      NULL,
    [RedemptionNumberPerClub] BIGINT        NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_AviosRedemptionPush_RedeemDate]
    ON [InsightArchive].[AviosRedemptionPush_20180322_Redemptions]([InitialRedeemDate] ASC);

