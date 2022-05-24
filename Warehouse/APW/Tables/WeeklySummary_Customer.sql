CREATE TABLE [APW].[WeeklySummary_Customer] (
    [CompositeID]      BIGINT NOT NULL,
    [PublisherID]      INT    NOT NULL,
    [ActivationDate]   DATE   NOT NULL,
    [DeactivationDate] DATE   NULL,
    CONSTRAINT [PK_APW_WeeklySummary_Customer] PRIMARY KEY CLUSTERED ([CompositeID] ASC)
);

