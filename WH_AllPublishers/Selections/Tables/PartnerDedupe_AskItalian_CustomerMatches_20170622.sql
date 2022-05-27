CREATE TABLE [Selections].[PartnerDedupe_AskItalian_CustomerMatches_20170622] (
    [HashedEmail]                VARCHAR (500) NULL,
    [FirstVoucherRedemptionDate] VARCHAR (50)  NULL,
    [FirstVoucherDownloadDate]   VARCHAR (50)  NULL,
    [Emailable]                  VARCHAR (50)  NULL,
    [Segment_ProofOFVisit]       VARCHAR (18)  NOT NULL,
    [Segment_Action]             VARCHAR (24)  NOT NULL,
    [Segment_EmailEngagement]    VARCHAR (20)  NOT NULL,
    [FanID]                      INT           NOT NULL,
    [Email]                      VARCHAR (30)  NULL
);

