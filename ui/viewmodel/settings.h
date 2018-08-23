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

#pragma once

#include <QObject>
#include <QSettings>

#include "model/wallet.h"

class SettingsViewModel : public QObject
{
	Q_OBJECT

	Q_PROPERTY(QString nodeAddress READ nodeAddress NOTIFY nodeAddressChanged)
	Q_PROPERTY(QString version READ version CONSTANT)
public:

	SettingsViewModel(const QString& iniPath);

	QString nodeAddress() const;
	QString version() const;

	void initModel(WalletModel::Ptr model);

public slots:
	void applyChanges(const QString& nodeAddr);
	void emergencyReset();

signals:
	void nodeAddressChanged();

private:
	QSettings _data;
	WalletModel::Ptr _model;
};