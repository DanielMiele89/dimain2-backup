CREATE TABLE [hayden].[CBP_Credit_TSYSIDToCINMapping_20210511] (
    [IssuerID]       INT           NOT NULL,
    [TSYSCIN]        NVARCHAR (11) NOT NULL,
    [CIN]            NVARCHAR (15) NULL,
    [DateCreated]    DATETIME2 (3) NOT NULL,
    [DateModified]   DATETIME2 (3) NOT NULL,
    [CINtoCINmerger] BIT           NOT NULL
);

