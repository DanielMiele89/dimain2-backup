CREATE TABLE [Prototype].[AirBnB_ALS_Splits] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

