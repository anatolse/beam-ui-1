// Copyright 2018 The Beam Team
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "settings.h"
#include "version.h"
#include <QtQuick>

namespace
{
	const char* NodeAddressName = "node/address";
}

SettingsViewModel::SettingsViewModel(const QString& iniPath)
	: _data(iniPath, QSettings::IniFormat)
{

}

void SettingsViewModel::initModel(WalletModel::Ptr model)
{
	_model = model;
}

QString SettingsViewModel::nodeAddress() const
{
	return _data.value(NodeAddressName).toString();
}

QString SettingsViewModel::version() const
{
	return QString::fromStdString(PROJECT_VERSION);
}

void SettingsViewModel::applyChanges(const QString& addr)
{
	if (addr != nodeAddress())
	{
		_data.setValue(NodeAddressName, addr);

		if(_model)
			_model->async->setNodeAddress(addr.toStdString());

		emit nodeAddressChanged();
	}
}

void SettingsViewModel::emergencyReset()
{
	if (_model)
		_model->async->emergencyReset();
}