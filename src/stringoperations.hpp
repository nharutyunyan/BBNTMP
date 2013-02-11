/*
 * stringoperations.hpp
 *
 *  Created on: 07/02/2013
 *      Author: lkarapetyan
 */

#ifndef STRINGOPERATIONS_HPP_
#define STRINGOPERATIONS_HPP_

#include <string>
#include <sstream>

class StringOperations
{
public:

    template<typename T>
    static std::string toString(const T& numeric)
    {
        std::stringstream ss;
        ss << numeric;

        return ss.str();
    }
};

#endif /* STRINGOPERATIONS_HPP_ */
