// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#ifndef ALLOFFILTER_H
#define ALLOFFILTER_H

#include "filtercontainerfilter.h"

namespace qqsfpm {

class AllOfFilter : public FilterContainerFilter {
    Q_OBJECT

public:
    using FilterContainerFilter::FilterContainerFilter;

protected:
    bool filterRow(const QModelIndex& sourceIndex, const QQmlSortFilterProxyModel& proxyModel) const override;
};

}

#endif // ALLOFFILTER_H
