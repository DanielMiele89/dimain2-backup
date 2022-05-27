CREATE TABLE [MI].[RetailerProspect_NonCoreSpend] (
    [ID]       INT      IDENTITY (1, 1) NOT NULL,
    [MonthID]  TINYINT  NOT NULL,
    [BrandID]  SMALLINT NOT NULL,
    [Spend]    MONEY    NOT NULL,
    [Spenders] INT      NOT NULL,
    CONSTRAINT [PK_MI_RetailerProspect_NonCoreSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

