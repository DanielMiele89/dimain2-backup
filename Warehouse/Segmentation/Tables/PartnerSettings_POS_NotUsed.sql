CREATE TABLE [Segmentation].[PartnerSettings_POS_NotUsed] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT      NOT NULL,
    [Acquire]           SMALLINT NOT NULL,
    [Lapsed]            SMALLINT NOT NULL,
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NULL,
    [AutoRun]           BIT      NOT NULL,
    [Shopper]           SMALLINT NOT NULL,
    [RegisteredAtLeast] SMALLINT NULL
);

