CREATE TABLE [Rory].[WH_Visa_Segmentation_OfferMemberAddition] (
    [ID]             BIGINT   NOT NULL,
    [CompositeID]    BIGINT   NOT NULL,
    [IronOfferID]    INT      NOT NULL,
    [StartDate]      DATETIME NOT NULL,
    [EndDate]        DATETIME NULL,
    [AddedDate]      DATETIME NULL,
    [NewIronOfferID] INT      NOT NULL
);

