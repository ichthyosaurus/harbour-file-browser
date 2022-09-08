/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
 * SPDX-FileCopyrightText: 2013 peppe
 *
 * SPDX-License-Identifier: GPL-3.0-only
 *
 * This file may be used under a later version of GPL if compatibility is
 * listed by Creative Commons: https://creativecommons.org/compatiblelicenses
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

// Adapted from https://stackoverflow.com/a/16795664
// CC BY-SA 4.0
template<typename... Args> struct choose {
    template<typename C, typename R>
    static constexpr auto overload_of( R (C::*ptr_to_member_func)(Args...) ) -> decltype(ptr_to_member_func) {
        return ptr_to_member_func;
    }
};
