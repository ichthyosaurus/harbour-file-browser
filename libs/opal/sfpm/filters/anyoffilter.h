// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#ifndef ANYOFFILTER_H
#define ANYOFFILTER_H

#include "filtercontainerfilter.h"

namespace qqsfpm {

class AnyOfFilter : public FilterContainerFilter {
    Q_OBJECT

public:
    using FilterContainerFilter::FilterContainerFilter;

protected:
    bool filterRow(const QModelIndex& sourceIndex, const QQmlSortFilterProxyModel& proxyModel) const override;
};

}

#endif // ANYOFFILTER_H
