CREATE TABLE [MI].[RetailerProspect_CoreSpend] (
    [ID]       INT      IDENTITY (1, 1) NOT NULL,
    [MonthID]  TINYINT  NOT NULL,
    [BrandID]  SMALLINT NOT NULL,
    [Spend]    MONEY    NOT NULL,
    [Spenders] INT      NOT NULL,
    CONSTRAINT [PK_MI_RetailerProspect_CoreSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

