CREATE TABLE [InsightArchive].[QBR_Toolkit_OFFER_DEMOGRAPHIC] (
    [main_brand]                VARCHAR (50)    NULL,
    [AgeCurrentBandText]        VARCHAR (10)    NULL,
    [Region]                    VARCHAR (30)    NULL,
    [Gender]                    CHAR (1)        NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)   NOT NULL,
    [Social_Class]              NVARCHAR (255)  NULL,
    [is_offer_responder]        VARCHAR (17)    NOT NULL,
    [ironoffername]             NVARCHAR (4000) NOT NULL,
    [CUSTOMERS]                 INT             NULL,
    [Isonline]                  INT             NULL
);

