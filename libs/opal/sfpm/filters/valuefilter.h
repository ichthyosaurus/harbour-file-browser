// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#ifndef VALUEFILTER_H
#define VALUEFILTER_H

#include "rolefilter.h"
#include <QVariant>

namespace qqsfpm {

class ValueFilter : public RoleFilter {
    Q_OBJECT
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)

public:
    using RoleFilter::RoleFilter;

    const QVariant& value() const;
    void setValue(const QVariant& value);

protected:
    bool filterRow(const QModelIndex &sourceIndex, const QQmlSortFilterProxyModel& proxyModel) const override;

Q_SIGNALS:
    void valueChanged();

private:
    QVariant m_value;
};

}

#endif // VALUEFILTER_H
