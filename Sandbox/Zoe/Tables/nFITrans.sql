CREATE TABLE [Zoe].[nFITrans] (
    [MerchantID]            NVARCHAR (19) NULL,
    [CardholderPresentData] INT           NOT NULL,
    [TransactionDate]       DATE          NULL,
    [AddedDate]             DATETIME      NOT NULL,
    [CompositeID]           BIGINT        NULL,
    [Amount]                SMALLMONEY    NOT NULL,
    [CardTypeID]            TINYINT       NOT NULL,
    [PartnerID]             INT           NULL,
    [VectorMajorID]         INT           NOT NULL,
    [VectorMinorID]         INT           NOT NULL
);

