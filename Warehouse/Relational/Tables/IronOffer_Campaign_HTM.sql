CREATE TABLE [Relational].[IronOffer_Campaign_HTM] (
    [ClientServicesRef]   VARCHAR (40)    NULL,
    [PartnerID]           INT             NULL,
    [EPOCU]               VARCHAR (1)     NULL,
    [HTMSegment]          INT             NULL,
    [IronOfferID]         INT             NOT NULL,
    [CashbackRate]        REAL            NULL,
    [CommissionRate]      NUMERIC (32, 2) NULL,
    [BaseOfferID]         INT             NULL,
    [Base_CashbackRate]   REAL            NULL,
    [Base_CommissionRate] NUMERIC (32, 2) NULL,
    [AboveBase]           INT             NULL,
    [isConditionalOffer]  BIT             NULL,
    [ID]                  INT             IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [pk_IronOfferID] PRIMARY KEY CLUSTERED ([IronOfferID] ASC),
    CONSTRAINT [UQ_Relational_IronOffer_Campaign_HTM_IronOfferID] UNIQUE NONCLUSTERED ([IronOfferID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[IronOffer_Campaign_HTM] TO [ExcelQuery_DataOps]
    AS [dbo];

