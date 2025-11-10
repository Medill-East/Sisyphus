// Copyright 2021-2024 Mickael Daniel. All Rights Reserved.

#include "Core/Settings/GSCDeveloperSettingsAttributes.h"

#include "AttributeSet.h"
#include "GSCLog.h"
#include "Abilities/Attributes/GSCAttributeSet.h"
#include "UObject/Class.h"

UGSCDeveloperSettingsAttributes::UGSCDeveloperSettingsAttributes()
{
}

const UGSCDeveloperSettingsAttributes& UGSCDeveloperSettingsAttributes::Get()
{
	const UGSCDeveloperSettingsAttributes* Settings = GetDefault<UGSCDeveloperSettingsAttributes>();
	check(Settings);
	return *Settings;
}

UGSCDeveloperSettingsAttributes& UGSCDeveloperSettingsAttributes::GetMutable()
{
	UGSCDeveloperSettingsAttributes* Settings = GetMutableDefault<UGSCDeveloperSettingsAttributes>();
	check(Settings);
	return *Settings;
}

FName UGSCDeveloperSettingsAttributes::GetCategoryName() const
{
	return PluginCategoryName;
}

#if WITH_EDITOR
FText UGSCDeveloperSettingsAttributes::GetSectionText() const
{
	return NSLOCTEXT("GSCDeveloperSettingsAttributes", "Attributes", "Attributes");
}

void UGSCDeveloperSettingsAttributes::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	
	static const FName HideInDetailsViewPropertyName = GET_MEMBER_NAME_CHECKED(UGSCDeveloperSettingsAttributes, bShouldHideGSCAttributeSetInDetailsView);
	const FName PropertyName = PropertyChangedEvent.Property ? PropertyChangedEvent.Property->GetFName() : NAME_None;

	if (PropertyName == HideInDetailsViewPropertyName)
	{
		SetHideInDetailsViewMetaData(UGSCAttributeSet::StaticClass(), bShouldHideGSCAttributeSetInDetailsView);
	}
}

void UGSCDeveloperSettingsAttributes::SetHideInDetailsViewMetaData(UClass* InClass, const bool bInHideInDetailsView)
{
	check(InClass);
	checkf(InClass->IsChildOf(UAttributeSet::StaticClass()), TEXT("InClass %s is not a UAttributeSet class"), *InClass->GetName());

	static const FString Key = TEXT("HideInDetailsView");
	if (bInHideInDetailsView)
	{
		InClass->SetMetaData(*Key, TEXT("true"));
		GSC_PLOG(Verbose, TEXT("%s metadata has been set for %s class"), *Key, *InClass->GetName())
	}
	else
	{
		InClass->RemoveMetaData(*Key);
		GSC_PLOG(Verbose, TEXT("%s metadata has been removed for %s class"), *Key, *InClass->GetName())
	}
}
#endif
