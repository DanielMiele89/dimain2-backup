CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Partner_Settings] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT      NOT NULL,
    [Acquire]           SMALLINT NOT NULL,
    [Lapsed]            SMALLINT NOT NULL,
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NULL,
    [AutoRun]           BIT      DEFAULT ((0)) NOT NULL,
    [Shopper]           SMALLINT CONSTRAINT [Shopper_default_value] DEFAULT ((0)) NOT NULL,
    [RegisteredAtLeast] SMALLINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

