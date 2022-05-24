CREATE TABLE [APW].[ForecastWeighting_Staging] (
    [ID]           INT   IDENTITY (1, 1) NOT NULL,
    [RetailerID]   INT   NOT NULL,
    [ForecastDate] DATE  NOT NULL,
    [Spend]        MONEY NOT NULL,
    CONSTRAINT [PK_APW_ForecastWeighting_Staging] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UCIX_ForecastWeighting_Staging]
    ON [APW].[ForecastWeighting_Staging]([RetailerID] ASC, [ForecastDate] ASC);

