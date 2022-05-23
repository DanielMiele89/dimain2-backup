CREATE TABLE [dbo].[CBP_RetailerGroup_TransactionStore] (
    [VectorID]             INT             NOT NULL,
    [VectorMajorID]        INT             NOT NULL,
    [VectorMinorID]        INT             NOT NULL,
    [IronOfferID]          INT             NOT NULL,
    [MerchantID]           NVARCHAR (50)   NOT NULL,
    [TranDate]             DATE            NOT NULL,
    [Amount]               DECIMAL (19, 4) NOT NULL,
    [PanID]                INT             NOT NULL,
    [MerchantCategoryCode] CHAR (4)        NULL,
    [MerchantNarrative]    NVARCHAR (50)   NULL,
    [MerchantLocation]     NVARCHAR (60)   NULL,
    [MerchantState]        NVARCHAR (3)    NULL,
    [MerchantCountry]      NVARCHAR (3)    NULL,
    [RetailOutletID]       INT             NULL,
    [PartnerID]            INT             NULL,
    [TranStatus]           INT             NOT NULL,
    [MatchID]              INT             NULL,
    [FanID]                INT             NOT NULL,
    CONSTRAINT [pk_RetailerGroupTranStore] PRIMARY KEY CLUSTERED ([VectorID] ASC, [VectorMajorID] ASC, [VectorMinorID] ASC, [IronOfferID] ASC, [PanID] ASC)
);

