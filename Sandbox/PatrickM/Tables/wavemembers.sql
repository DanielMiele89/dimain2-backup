CREATE TABLE [PatrickM].[wavemembers] (
    [IronOfferID]                 INT           NOT NULL,
    [PartnerID]                   INT           NULL,
    [PartnerName]                 VARCHAR (100) NULL,
    [IronOfferMemberID]           BIGINT        NOT NULL,
    [CompositeID]                 BIGINT        NULL,
    [Wave_1_OfferMemberStartDate] DATETIME      NULL,
    [Wave_1_OfferMemberEndDate]   DATETIME      NULL,
    [Wave_1_OfferImportDate]      DATETIME      NULL,
    [FanID]                       INT           NULL
);

