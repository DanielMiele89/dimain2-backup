


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 13/06/2016
-- Description: Shows all unbranded Airline records in the specified MCC's.
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[Ijaz_Airlines_Unbranded]
						
			
AS

	SET NOCOUNT ON;



/***************************************************************************
********* Bring back ALL unbranded records for the specified MCC's *********
***************************************************************************/
SELECT		cc.BrandID AS CC_BrandID
,			b.Brandname AS CC_Brandname
,			cc.ConsumerCombinationID
,			cc.MID
,			cc.Narrative
,			LocationCountry
,			mcc.MCC
,			mcc.MCCDesc
,			air.BrandID
,			air.BrandName
INTO		#T1
FROM		Warehouse.Relational.ConsumerCombination AS CC WITH (NOLOCK)
INNER JOIN	Warehouse.Relational.MCCList AS mcc
	ON		cc.MCCID = mcc.MCCID
INNER JOIN	Warehouse.Relational.Brand AS b
	ON		cc.BrandID = b.BrandID
INNER JOIN	Warehouse.Staging.Airlines_BrandvsMCC air
	ON		mcc.MCC = air.MCC
LEFT OUTER JOIN Warehouse.Staging.BrandSuggestionRejected bsr
	ON		cc.ConsumerCombinationID = bsr.ConsumerCombinationID
	AND		air.BrandID = bsr.BrandID
WHERE		mcc.MCC IN (3000,3001,3004,3005,3006,3007,3009,3010,3014,3015,3016,3017,3020,3021,3022,3025,3026,3028,3031,3033,3034,3037,3038,3040,3041,3042,3044,3045,3048,3049,3050,3051,3056,3057,3063,3064,3065,3066,3067,3068,3071,3075,3077,3078,3079,3081,3082,3083,3084,3085,3086,3087,3088,3090,3092,3094,3095,3096,3097,3098,3100,3110,3115,3118,3125,3126,3129,3130,3131,3132,3133,3135,3136,3137,3138,3143,3145,3146,3148,3151,3159,3161,3164,3171,3172,3174,3175,3176,3177,3178,3180,3181,3182,3183,3190,3191,3192,3193,3196,3197,3200,3203,3204,3206,3211,3213,3215,3216,3218,3222,3223,3226,3228,3233,3235,3236,3239,3240,3243,3245,3246,3247,3248,3251,3252,3254,3256,3259,3260,3261,3262,3266,3267,3280,3282,3292,3294,3295,3296,3297,3298)
	AND		cc.BrandID = 944
	AND		bsr.ConsumerCombinationID IS NULL
ORDER BY	mcc.MCCDesc

SELECT		*
FROM		#T1
ORDER BY	MCCDesc,Narrative

--EXEC Warehouse.Prototype.Ijaz_Airlines_Unbranded