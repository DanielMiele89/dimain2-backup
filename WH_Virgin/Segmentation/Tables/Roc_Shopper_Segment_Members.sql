CREATE TABLE [Segmentation].[Roc_Shopper_Segment_Members] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                INT      NOT NULL,
    [PartnerID]            INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NOT NULL,
    [StartDate]            DATE     NOT NULL,
    [EndDate]              DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Segmentation].[Roc_Shopper_Segment_Members] TO [gabor]
    AS [dbo];

