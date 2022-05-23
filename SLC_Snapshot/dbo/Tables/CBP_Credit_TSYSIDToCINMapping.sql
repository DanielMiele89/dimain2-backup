CREATE TABLE [dbo].[CBP_Credit_TSYSIDToCINMapping] (
    [IssuerID]       INT           NOT NULL,
    [TSYSCIN]        NVARCHAR (11) NOT NULL,
    [CIN]            NVARCHAR (15) NULL,
    [DateCreated]    DATETIME      NOT NULL,
    [DateModified]   DATETIME      NOT NULL,
    [CINtoCINmerger] BIT           NOT NULL,
    CONSTRAINT [PK_CBP_Credit_CustomerTSYSIDToCINMapping] PRIMARY KEY CLUSTERED ([IssuerID] ASC, [TSYSCIN] ASC)
);

