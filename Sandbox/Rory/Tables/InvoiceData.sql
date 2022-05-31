CREATE TABLE [Rory].[InvoiceData] (
    [Publisher]                        NVARCHAR (100) NULL,
    [Partner]                          NVARCHAR (501) NULL,
    [NormalisedPartner]                NVARCHAR (501) NULL,
    [DateOfTrans]                      DATE           NULL,
    [InvoiceNumber]                    NVARCHAR (8)   NOT NULL,
    [InvoiceDate]                      DATE           NULL,
    [Spend]                            MONEY          NULL,
    [ClubCash]                         MONEY          NULL,
    [Gross]                            MONEY          NULL,
    [VAT]                              MONEY          NULL,
    [NetOver]                          MONEY          NULL,
    [Transactions]                     INT            NULL,
    [TransWithNetOverMoreThan20p]      INT            NULL,
    [RefundsWithNetOverLessThanNeg20p] INT            NULL
);

