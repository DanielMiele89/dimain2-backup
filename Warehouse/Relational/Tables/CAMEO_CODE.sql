CREATE TABLE [Relational].[CAMEO_CODE] (
    [CAMEO_CODE]                      NVARCHAR (3)   NOT NULL,
    [CAMEO_CODE_GROUP]                VARCHAR (2)    NULL,
    [CAMEO_INTL]                      INT            NULL,
    [CAMEO_CODE_Category]             NVARCHAR (255) NULL,
    [Pct_of_UK_Households]            FLOAT (53)     NULL,
    [Presence_of_Children]            NVARCHAR (255) NULL,
    [Adult_Index_18_44]               INT            NULL,
    [Adult_Index_Over_44]             INT            NULL,
    [Singles]                         NVARCHAR (255) NULL,
    [Couples]                         NVARCHAR (255) NULL,
    [Families]                        NVARCHAR (255) NULL,
    [Social_Class]                    NVARCHAR (255) NULL,
    [Urbanity_Index]                  INT            NULL,
    [Housing_Type]                    NVARCHAR (255) NULL,
    [Tenure]                          NVARCHAR (255) NULL,
    [Property_Value_Index]            INT            NULL,
    [Number_of_Rooms_exc_Bathrooms]   NVARCHAR (255) NULL,
    [Household_Income_over_30K_Index] INT            NULL,
    [Educational_Qualifications]      NVARCHAR (255) NULL,
    [Index_of_Directors]              INT            NULL,
    [Index_of_Students]               NVARCHAR (255) NULL,
    [Unemployment_Index]              NVARCHAR (255) NULL,
    [Investor_Index]                  INT            NULL,
    [Credit_Card_Ownership]           NVARCHAR (255) NULL,
    [Credit_Risk]                     NVARCHAR (255) NULL,
    [Smartphone_Ownership_Index]      INT            NULL,
    [Tablet_Ownership_Index]          INT            NULL,
    [Weekly_Internet_Use]             NVARCHAR (255) NULL,
    [Daily_Social_Media_Use]          NVARCHAR (255) NULL,
    [Online_Shopping_Frequency]       NVARCHAR (255) NULL,
    [Groceries]                       INT            NULL,
    [Train_Tickets]                   INT            NULL,
    [Flights]                         INT            NULL,
    [Holidays]                        INT            NULL,
    [Fashion]                         INT            NULL,
    [Books]                           INT            NULL,
    [Newspaper_Readership]            NVARCHAR (255) NULL,
    [Hours_of_Sport_Per_Week]         INT            NULL,
    [Over_2_Holidays_Abroad]          INT            NULL,
    CONSTRAINT [pk_CAMEO_CODE] PRIMARY KEY CLUSTERED ([CAMEO_CODE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CINTL]
    ON [Relational].[CAMEO_CODE]([CAMEO_INTL] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CCGROUP]
    ON [Relational].[CAMEO_CODE]([CAMEO_CODE_GROUP] ASC);

