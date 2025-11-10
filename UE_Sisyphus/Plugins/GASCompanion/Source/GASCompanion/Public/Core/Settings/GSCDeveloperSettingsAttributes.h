// Copyright 2021-2024 Mickael Daniel. All Rights Reserved.

#pragma once

#include "Engine/DeveloperSettings.h"
#include "GSCDeveloperSettingsAttributes.generated.h"

class UAttributeSet;

/**
 * Developer Settings for GAS Companion, Attributes and AttributeSets related config.
 *
 * Upon changing any of the below configuration settings, the `Config/DefaultGame.ini` file will be saved to persist
 * this setting.
 */
UCLASS(config=Game, defaultconfig)
class GASCOMPANION_API UGSCDeveloperSettingsAttributes : public UDeveloperSettings
{
	GENERATED_BODY()

public:
	/**
	 * Enable this setting to hide GSCAttributeSet attributes from appearing in the Gameplay Attributes dropdown,
	 * specifically in Gameplay Effects and K2 nodes like GetFloatAttribute() and their Attribute pin parameter.
	 */
	UPROPERTY(config, EditAnywhere, Category = "Attributes")
	bool bShouldHideGSCAttributeSetInDetailsView = false;

	/** Default constructor */
	UGSCDeveloperSettingsAttributes();

	static const UGSCDeveloperSettingsAttributes& Get();
	static UGSCDeveloperSettingsAttributes& GetMutable();

	/**
	 * The category name for our developer settings
	 *
	 * @see GetCategoryName
	 */
	static constexpr const TCHAR* PluginCategoryName = TEXT("GAS Companion");

	//~ Begin UDeveloperSettings interface
	virtual FName GetCategoryName() const override;
#if WITH_EDITOR
	virtual FText GetSectionText() const override;
	//~ End UDeveloperSettings interface
	
	//~ Begin UObject interface
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
	//~ End UObject interface

	/** Adds or remove `HideInDetailsView` class metadata to the passed in UClass. InClass must be a child of UAttributeSet */
	static void SetHideInDetailsViewMetaData(UClass* InClass, bool bInHideInDetailsView);
#endif
};
