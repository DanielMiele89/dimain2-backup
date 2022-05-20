CREATE TABLE [COD].[ForecastItem] (
    [ID]        INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BriefID]   INT            NOT NULL,
    [key_name]  NVARCHAR (64)  NOT NULL,
    [key_value] NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK__Forecast__3214EC277A9C46D9] PRIMARY KEY CLUSTERED ([ID] ASC)
);

