CREATE TABLE [InsightArchive].[FansEarning] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         INT          NOT NULL,
    [EarningsYear]  SMALLINT     NOT NULL,
    [PaymentMethod] TINYINT      NOT NULL,
    [EarningTable]  VARCHAR (50) NOT NULL,
    [Earnings]      MONEY        NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

