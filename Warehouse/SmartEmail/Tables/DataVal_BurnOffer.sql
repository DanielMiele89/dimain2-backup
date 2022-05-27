CREATE TABLE [SmartEmail].[DataVal_BurnOffer] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [FanID_Profile]           VARCHAR (255) NULL,
    [FanID_Offer]             VARCHAR (255) NULL,
    [ClubID]                  VARCHAR (255) NULL,
    [EmailAddress]            VARCHAR (255) NULL,
    [CashbackAvailable]       VARCHAR (255) NULL,
    [CashbackPending]         VARCHAR (255) NULL,
    [LifetimeValue]           VARCHAR (255) NULL,
    [IsDebit]                 VARCHAR (255) NULL,
    [IsCredit]                VARCHAR (255) NULL,
    [LoyaltyAccount]          VARCHAR (255) NULL,
    [CustomerSegment]         VARCHAR (255) NULL,
    [EmailSendID]             VARCHAR (255) NULL,
    [EmailSendName]           VARCHAR (255) NULL,
    [CreationMoment_Profile]  VARCHAR (255) NULL,
    [UpdateMoment_Profile]    VARCHAR (255) NULL,
    [BurnOfferID_Hero]        VARCHAR (255) NULL,
    [BurnOfferID_1]           VARCHAR (255) NULL,
    [BurnOfferID_2]           VARCHAR (255) NULL,
    [BurnOfferID_3]           VARCHAR (255) NULL,
    [BurnOfferID_4]           VARCHAR (255) NULL,
    [BurnOfferStartDate_Hero] VARCHAR (255) NULL,
    [BurnOfferStartDate_1]    VARCHAR (255) NULL,
    [BurnOfferStartDate_2]    VARCHAR (255) NULL,
    [BurnOfferStartDate_3]    VARCHAR (255) NULL,
    [BurnOfferStartDate_4]    VARCHAR (255) NULL,
    [BurnOfferEndDate_Hero]   VARCHAR (255) NULL,
    [BurnOfferEndDate_1]      VARCHAR (255) NULL,
    [BurnOfferEndDate_2]      VARCHAR (255) NULL,
    [BurnOfferEndDate_3]      VARCHAR (255) NULL,
    [BurnOfferEndDate_4]      VARCHAR (255) NULL,
    [CreationMoment_Offer]    VARCHAR (255) NULL,
    [UpdateMoment_Offer]      VARCHAR (255) NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [SmartEmail].[DataVal_BurnOffer]([FanID_Offer] ASC);

