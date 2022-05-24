CREATE TABLE [Segmentation].[PartnerSettings_DD] (
    [ID]        INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT      NOT NULL,
    [Acquire]   SMALLINT NOT NULL,
    [Lapsed]    SMALLINT NOT NULL,
    [Shopper]   SMALLINT DEFAULT ((0)) NOT NULL,
    [AutoRun]   BIT      DEFAULT ((0)) NOT NULL,
    [StartDate] DATE     NOT NULL,
    [EndDate]   DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

