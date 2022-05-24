CREATE TABLE [Prototype].[ChristmasRedemptionPushCheck_RF] (
    [FanID]         INT          NOT NULL,
    [CustomerGroup] VARCHAR (15) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Prototype].[ChristmasRedemptionPushCheck_RF]([FanID] ASC);

