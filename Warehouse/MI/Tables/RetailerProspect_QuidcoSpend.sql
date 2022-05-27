CREATE TABLE [MI].[RetailerProspect_QuidcoSpend] (
    [ID]       INT      IDENTITY (1, 1) NOT NULL,
    [MonthID]  TINYINT  NOT NULL,
    [BrandID]  SMALLINT NOT NULL,
    [Spend]    MONEY    NOT NULL,
    [Spenders] INT      NOT NULL,
    CONSTRAINT [PK_MI_RetailerProspect_QuidcoSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

